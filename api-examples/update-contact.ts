/**
 * Next.js API Route - Kişi/Contact Güncelleme
 * Flutter myoffice_edit_screen ve edit_person_screen bu endpoint'i kullanır.
 * 
 * Kullanım: pages/api/zecorner/contact/[no].ts veya app/api/zecorner/contact/[no]/route.ts
 * Flutter: POST http://3.77.159.125/api/zecorner/contact/{contactNo}?type=detail
 */

import axios from "axios";
import { NextApiRequest, NextApiResponse } from "next";

import { parseErrorPayload } from "@/utils/api/api-error-codes";
import saveContactValidation from "@/utils/api/validations/saveContact.validation";
import APIMiddleware, {
  IAPIMiddlewareResponse,
  REQUEST_METHOD,
} from "@/utils/api/APIMiddleware";

export const config = {
  api: {
    bodyParser: {
      sizeLimit: "10mb",
    },
  },
};

const endpoint = "/contact";

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  try {
    const apiRes = await APIMiddleware(
      req,
      REQUEST_METHOD.POST,
      saveContactValidation,
      true
    );
    const { values: requestBody, headers } =
      apiRes as IAPIMiddlewareResponse<any>;

    let attachments: { type: string; attachment: string }[] = [];
    let picture: string | undefined, logo: string | undefined;

    if (requestBody.files && (requestBody.files ?? []).length > 0) {
      await Promise.all(
        requestBody.files.map(async (file: any) => {
          const s3Id = file.s3Id;
          if (s3Id && file.id !== "PICTURE" && file.id !== "LOGO") {
            attachments.push({
              type: file.id,
              attachment: s3Id,
            });
          } else if (file.id === "PICTURE") {
            picture = s3Id;
          } else if (file.id === "LOGO") {
            logo = s3Id;
          }
        })
      );
    }

    requestBody.detail = requestBody.detail ?? {};
    requestBody.detail.attachments = [
      ...(requestBody?.detail?.attachments ?? []),
      ...attachments,
    ];

    if (picture) {
      requestBody.detail.picture = picture;
    }
    if (logo) {
      requestBody.detail.logo = logo;
    }

    if (!requestBody.starting_rate) {
      delete requestBody.starting_rate;
    }

    delete requestBody.files;

    // Güncelleme: POST /contact/{no} (req.query.no veya dynamic route [no])
    const contactNo = req.query.no ?? (req as any).query?.no;
    if (!contactNo) {
      return res.status(400).json({ message: "Contact numarası gerekli (no)" });
    }

    const saveContactResponse = await axios.post(
      `${process.env.BAMMA_APP_URL}${endpoint}/${contactNo}`,
      requestBody,
      {
        headers: {
          ...headers,
          "X-API-KEY": process.env.X_API_KEY,
          "X-APP-ID": process.env.X_APP_ID,
        },
      }
    );

    return res.status(200).json({ result: saveContactResponse.data });
  } catch (error) {
    console.log(error);
    const { status, message } = parseErrorPayload(error);
    return res.status(status).json(message);
  }
}
